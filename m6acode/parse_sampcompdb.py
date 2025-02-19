import numpy as np
from nanocompore.SampCompDB import SampCompDB
from sklearn.preprocessing import StandardScaler
from collections import *
from nanocompore.common import *
import sys
import ast
from tqdm import tqdm

dbdir = sys.argv[1]
reference_transcriptome=sys.argv[2]
#tx='ENST00000331789'
db = SampCompDB(dbdir+"/out_SampComp.db", fasta_fn=reference_transcriptome)
tx=sys.argv[3]
if(sys.argv[4]=="all"):
    poi_list=list(range(0,len(db[tx])))
else:
    poi_list=ast.literal_eval(sys.argv[4])

#for pos in poi_list:
#    p1=db.plot_position(ref_id=tx, pos=pos, plot_style='seaborn-whitegrid', figsize=[14,10], pointSize=10)
#    p1[0].savefig("Actb_"+str(pos)+".svg")

modified_reads=dict()
outfile = open(dbdir+"/out.tsv", "w")
outfile2 = open(dbdir+"/out_data.tsv", "w")
for poi in tqdm(poi_list):
    if(db[tx][poi]['lowCov']): 
        continue
    data = db[tx][poi]['data']
    condition_labels = tuple(["WT", "KD"])
    sample_labels = ['WT_1', 'WT_2', 'KD_1', 'KD_2']
    global_intensity = np.concatenate(([v['intensity'] for v in data[condition_labels[0]].values()]+[v['intensity'] for v in data[condition_labels[1]].values()]), axis=None)
    global_dwell = np.concatenate(([v['dwell'] for v in data[condition_labels[0]].values()]+[v['dwell'] for v in data[condition_labels[1]].values()]), axis=None)
    global_reads = np.concatenate(([v['reads'] for v in data[condition_labels[0]].values()]+[v['reads'] for v in data[condition_labels[1]].values()]), axis=None)
    global_dwell = np.log10(global_dwell)
    # Scale the intensity and dwell time arrays
    X = StandardScaler().fit_transform([(i, d) for i,d in zip(global_intensity, global_dwell)])
    Y = [ k for k,v in data[condition_labels[0]].items() for _ in v['intensity'] ] + [ k for k,v in data[condition_labels[1]].items() for _ in v['intensity'] ]

    # try to extract the model
    try:
        model=db[tx][poi]['txComp']['GMM_model']['model']
    except KeyError:
        for read, lab in zip(global_reads, Y):
            outfile.write("\t".join([lab, str(poi), read, str(0)])+"\n")
        for intensity, dwell, lab in zip(global_intensity, global_dwell, Y):
            pred="Unmodified"
            outfile2.write("\t".join([str(poi), lab, str(pred), str(0), str(intensity), str(dwell)])+'\n')
        continue 

    y_pred_prob = model.predict_proba(X)
    y_pred = model.predict(X)
    logr=dict()
    labels=[]
    counters = dict()
    for lab in sample_labels:
        counters[lab] = Counter(y_pred[[i==lab for i in Y]])
    for sample,counter in counters.items():
           labels.append(sample)
           ordered_counter = [ counter[i]+1 for i in range(2)]
           total = sum(ordered_counter)
           normalised_ordered_counter = [ i/total for i in ordered_counter ]
           # Loop through ordered_counter and divide each value by the first
           logr[sample] = np.log(normalised_ordered_counter[0]/(1-normalised_ordered_counter[0]))
    
    if(np.mean([v for k,v in logr.items() if "KD" in k])<0):
        mod_cluster=0
    else:
        mod_cluster=1
    for read, p, lab in zip(global_reads, y_pred_prob, Y):
        outfile.write("\t".join([lab, str(poi), read, str(p[mod_cluster])])+"\n")
    for intensity, dwell, lab, pred, p in zip(global_intensity, global_dwell, Y, y_pred, y_pred_prob):
        if pred == mod_cluster:
            pred="Modified"
        else:
            pred="Unmodified"
        outfile2.write("\t".join([str(poi), lab, str(pred), str(p[mod_cluster]), str(intensity), str(dwell)])+'\n')
outfile.close()
outfile2.close()
