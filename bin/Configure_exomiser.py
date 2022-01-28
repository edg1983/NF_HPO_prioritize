#!/usr/bin/python
import argparse

def tokenize(x, sep="\t"):
    x = x.rstrip("\n")
    x = x.split(sep)
    return(x)

#arguments
parser = argparse.ArgumentParser(description='Configure exomiser analysis yml file')
parser.add_argument("-p", "--hpo", help="HPO profiles tsv (caseID then 1 HPO id per col)", action="store", required=True)
parser.add_argument("-i", "--input", help="input file tsv (caseID,proband_id,vcf,ped)", action="store", required=True)
parser.add_argument("-t", "--template", help=".yml template file", action="store", required=True)
args = parser.parse_args()

#Read HPOs into dict
hpos = {}
with open(args.hpo) as f:
    for line in f:
        line = tokenize(line)
        hpos[line[0]] = ",".join(["'" + x + "'" for x in line[1:]])

#Read input
inputs = {}
with open(args.input) as f:
    for line in f:
        line = tokenize(line)
        inputs[line[0]] = {}
        inputs[line[0]]['proband'] = line[1]
        inputs[line[0]]['vcf'] = line[2]
        inputs[line[0]]['ped'] = line[3]
        
#Update template
for id, info in inputs.items():
    outfile = open(id + ".yml", "w")
    with open(args.template) as f:
        for line in f:
            if line.find("#") == -1:
                line = line.replace('vcf:', 'vcf: ' + info['vcf'])
                line = line.replace('ped:', 'ped: ' + info['ped'])
                line = line.replace('proband:', 'proband: ' + info['proband'])
                line = line.replace('hpoIds:', 'hpoIds: [' + hpos[id] + ']')
                line = line.replace('outputPrefix:', 'outputPrefix: ' + id)
                outfile.write(line)
    print("Created profile for ", id)
    outfile.close()