function c=tom_mirror(varargin)
%TOM_MIRROR Creation of the mirror of the input Image
%
%   c=tom_mirror(varargin)
%
%   C=TOM_MIRROR(A,'axe')  This function creates the mirror image of the input image
%   A. Depending on the special string axe, that can take the 'x','y' or 'z' value,
%   the direction of the corresponding axis is inverted.
%   Syntax : c=tom_mirror(a,'axe')
%
%PARAMETERS
%
%  INPUT
%   varargin            ...
%  
%  OUTPUT
%   c                   ...
%
%EXAMPLE
%       c=tom_mirror(a,'x')
%
%            1   2   3   4   5          21  22  23  24  25
%            6   7   8   9  10          16  17  18  19  20
%       a = 11  12  13  14  15     c =  11  12  13  14  15
%           16  17  18  19  20           6   7   8   9  10
%           21  22  23  24  25           1   2   3   4   5
%
%
%
%   c=tom_mirror(a,'y')
%
%            1   2   3   4   5          5    4   3   2   1
%            6   7   8   9  10          10   9   8   7   6
%       a = 11  12  13  14  15     c =  15  14  13  12  11
%           16  17  18  19  20          20  19  18  17  16
%           21  22  23  24  25          25  24  23  22  21
%
%REFERENCES
%
%SEE ALSO
%   TOM_LIMIT, TOM_PASTE, TOM_MOVE, TOM_RED
%
%   created by AL 08/09/02
%   optimized for speed by AK 10/08/07
%
%   Nickell et al., 'TOM software toolbox: acquisition and analysis for electron tomography',
%   Journal of Structural Biology, 149 (2005), 227-234.
%
%   Copyright (c) 2004-2007
%   TOM toolbox for Electron Tomography
%   Max-Planck-Institute of Biochemistry
%   Dept. Molecular Structural Biology
%   82152 Martinsried, Germany
%   http://www.biochem.mpg.de/tom


a=varargin{1};
dimsel=varargin{2};
[s1 s2 s3]=size(a);

c = zeros(s1,s2,s3,class(a));

switch (dimsel)
    
case 'x'
    for i=1:s3
        if nargin>2
            stmp=varargin{3};
        else            
            stmp=ceil(s1/2);
        end          
        p1=a(1:stmp,:,i);
        p2=a((stmp+1):s1,:,i);
        sizp1=size(p1);
        sizp2=size(p2);
        p3=padarray(p1,sizp1(1),'symmetric','post');
        p4=padarray(p2,sizp2(1),'symmetric','pre');
        l=size(p3);
        p3=p3((stmp+1):l(1),:);
        p4=p4(1:sizp2(1),:);
        c1=[p4;p3];
        c(:,:,i)=c1;
              
    end
    
    
case 'y'
    for i=1:s3
        if nargin>2
            stmp=varargin{3};
        else            
            stmp=ceil(s2/2);
        end
        p1=a(:,1:stmp,i);
        p2=a(:,(stmp+1):s2,i);
        sizp1=size(p1);
        sizp2=size(p2);
        p3=(padarray(p1',sizp1(2),'symmetric','post'))';
        p4=(padarray(p2',sizp2(2),'symmetric','pre'))';
        l=size(p3);
        p3=p3(:,(stmp+1):l(2));
        p4=p4(:,1:sizp2(2));
        c1=[p4 p3];
        c(:,:,i)=c1;
        
    end
    
case 'z'
    for i=1:s3
        c(:,:,i)=a(:,:,(s3+1)-i);
    end
   
otherwise 
    error('Unknown Dimension')
end


