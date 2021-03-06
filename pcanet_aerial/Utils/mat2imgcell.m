function Img = mat2imgcell(D,height,width,ImgFormat)

N = size(D,1); % change 1 to 2 if samples are columns
if strcmp(ImgFormat,'gray')
    Img = cell(N,1);
    for i = 1:N
        Img{i} = reshape(D(i,:),height,width);
    end
elseif strcmp(ImgFormat,'color')
    Img = cell(N,1);
    for i = 1:N
        Img{i} = reshape(D(i,:),height,width,3); % change D(i,:) to D(:,i) if samples are in columns
    end
elseif strcmp(ImgFormat,'color2THREEgray')
    Img = cell(3*N,1);
    for i = 1:N
        T = reshape(D(:,i),height,width,3);
        Img{(i-1)*3 + 1} = T(:,:,1);
        Img{(i-1)*3 + 2} = T(:,:,2);
        Img{(i-1)*3 + 3} = T(:,:,3);
    end

end
