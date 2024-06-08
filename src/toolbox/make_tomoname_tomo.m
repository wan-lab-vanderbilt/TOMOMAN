load("tomolist.mat")

for i = 1:numel(tomolist)
    tomo1_name = ['cryocare_bin4/' num2str(tomolist(i).tomo_num) '.mrc'];
    [~,tomo2,~] = fileparts(tomolist(i).mdoc_name);
    tomo2_name = ['/fs/pool/pool-visprot/archival/4empiar/prototyping/data/tomoman_minimal_project/cryocare_bin4_tomoname/' tomo2 '.mrc'];
    system(['cp ' tomo1_name ' ' tomo2_name]);
end