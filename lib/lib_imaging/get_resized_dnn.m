function dnn = get_resized_dnn(dnnFile, ImDims)

%% [in]
% dnnFile: string
%          path of DNN
% imDims: vect 2D
%          image dimension

%% [out]
% dnn: DNN
%      resized deep neural network

dnn = importONNXNetwork(dnnFile, 'OutputLayerType', 'regression');

lgraph = layerGraph(dnn);
lgraph = replaceLayer(lgraph, lgraph.Layers(1).Name, imageInputLayer(ImDims, 'Name', 'input_image', 'Normalization', 'none'));
dnn = assembleNetwork(lgraph);

end
