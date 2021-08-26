from collections import defaultdict

parse_file=lambda x:[l.split('\t') for l in open(x,'r').read().strip().split('\n')]
# use.facts -> where does a variable get used
# value.facts -> what value does a variable have
# def.facts -> where does a variable get defined
use_facts=parse_file("vo/use.facts")
value_facts=parse_file('vo/value.facts')
def_facts=parse_file('vo/def.facts')


use_pc_to_v={}
v_to_def=defaultdict(list)
v_to_val={}

for v,pc,x in use_facts:
    pc=int(pc,16)
    use_pc_to_v[pc]=v

for var,val in value_facts:
    val=int(val,16)
    v_to_val[var]=val

for var, defpc in def_facts:
    defpc=int(defpc,16)
    v_to_def[var]+=[defpc]

jumppc_to_pushpc=lambda x:v_to_def[use_pc_to_v[x]]
jumppc_to_val=lambda x:v_to_val[use_pc_to_v[x]]

block_facts=parse_file('vo/block.facts')
edge_facts=parse_file('vo/edge.facts')

pc_to_block={}

blocks_list=set()

for pc, block in block_facts:
    pc_to_block[pc]=block
    blocks_list.add(int(block,16))

blocks_list=sorted(blocks_list)

func_to_blocks=defaultdict(list)

pub_func_facts=parse_file('vo/public_function_sigs.facts')
in_func_facts=parse_file('vo/in_function.facts')

for e in pub_func_facts:
    if len(e)<2:
        continue
    id1, sig  = e
    for block, id2 in in_func_facts:
        if id1==id2:
            func_to_blocks[sig].append(int(block,16))
