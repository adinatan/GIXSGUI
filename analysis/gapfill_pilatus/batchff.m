function batchff
% ***********************************************
% Copyright (c) 2020 UChicago Argonne, LLC
% See LICENSE file.
% ***********************************************
%
% BATCHFF Apply flat field correction in batch mode.
%
%   Require imwrite2tif.m

%   Zhang Jiang @8ID/APS/ANL
%   $Revision: 1.0 $  $Date: 2011/02/28 $

hFigBatchFF = findall(0,'Tag','batchff_fig');
if ~isempty(hFigBatchFF)
    figure(hFigBatchFF);
    return;
end

%% initialize udata
udata.path = '';
udata.flist = {};
udata.fffile = '';
udata.ff = [];
udata.targetpath = '';
udata.prefix = 'FF_';
udata.bit = 'int32';

%% figure layout
screenSize = get(0,'screensize');
figSize = [380,420];
figPos = [(screenSize(3)-figSize(1))/2, (screenSize(4)-figSize(2))/2, figSize];
hFigBatchFF = figure(...
    'DockControls','off',...
    'Resize','off',...
	'position',figPos,...
    'PaperOrient','portrait',...
    'PaperPositionMode','auto',...
    'IntegerHandle','off',...
    'NumberTitle','off',...
    'MenuBar','none',...
    'HandleVisibility','callback',...
    'Toolbar','none',...
    'Name','Flat Field Correction - 1.0 (8ID/APS/ANL)',...
    'Tag','batchff_fig','UserData',udata);
backgroundcolor = get(hFigBatchFF,'color');
uicontrol('Parent',hFigBatchFF,...
    'style','Edit',...
    'Units','pixel',...
    'backgroundcolor','w',...
    'String','',...
    'Max',2,...
    'Min',0,...
    'HorizontalAlignment','left',...
    'Enable','inactive',...
    'Position',[5,80,figSize(1)-10,figSize(2)-85],...
    'Tag','batchff_msg');
uicontrol('Parent',hFigBatchFF,...
    'style','pushbutton',...
    'String','Load Image Path ...',...
    'unit','pixel',...
    'Position',[5,55,120,20],...
    'Tag','batchff_PushbuttonLoadPath',...
    'callback',@batchff_PushbuttonLoadPath);
uicontrol('Parent',hFigBatchFF,...
    'style','pushbutton',...
    'String','Load FF File ...',...
    'unit','pixel',...
    'Position',[5,30,120,20],...
    'Tag','batchff_PushbuttonLoadFF',...
    'callback',@batchff_PushbuttonLoadFF);
uicontrol('Parent',hFigBatchFF,...
    'style','pushbutton',...
    'String','Load Target Path ...',...
    'unit','pixel',...
    'Position',[130,55,120,20],...
    'Tag','batchff_PushbuttonLoadPath',...
    'callback',@batchff_PushbuttonLoadTargetPath);
uicontrol('Parent',hFigBatchFF,...
    'style','Text',...
    'Units','pixel',...
    'backgroundcolor',backgroundcolor,...
    'String','Pre_fix: ',...
    'HorizontalAlignment','right',...
    'Position',[130,30,50,15]);
uicontrol('Parent',hFigBatchFF,...
    'style','Edit',...
    'Units','pixel',...
    'backgroundcolor','w',...
    'String','FF_',...
    'HorizontalAlignment','left',...
    'Enable','on',...
    'Position',[185,30,65,20],...
    'Tag','batchff_EditPrefix',...
    'callback',@batchff_EditPrefix);
uicontrol('Parent',hFigBatchFF,...
    'style','Text',...
    'Units','pixel',...
    'backgroundcolor',backgroundcolor,...
    'String','Image type ',...
    'HorizontalAlignment','left',...
    'Position',[255,55,60,15]);
uicontrol('Parent',hFigBatchFF,...
    'style','Popupmenu',...
    'Units','pixel',...
    'backgroundcolor','w',...
    'String',{'logical','uint8','int8','uint16','int16','uint32','int32','single','uint64','int64','double'},...
    'value',7,...
    'HorizontalAlignment','left',...
    'Enable','on',...
    'Position',[315,55,60,20],...
    'Tag','batchff_PopupmenuBit',...
    'callback',@batchff_PopupmenuBit);
uicontrol('Parent',hFigBatchFF,...
    'style','pushbutton',...
    'String','Start',...
    'unit','pixel',...
    'Position',[255,30,120,20],...
    'Tag','batchff_PushbuttonStart',...
    'callback',@batchff_PushbuttonStart);

uicontrol('Parent',hFigBatchFF,...
    'style','pushbutton',...
    'String','Close',...
    'unit','pixel',...
    'Position',[5,5,100,20],...
    'Tag','batchff_PushbuttonClose',...
    'callback','delete(gcbf)');
uicontrol('Parent',hFigBatchFF,...
    'style','pushbutton',...
    'String','Clear Message',...
    'unit','pixel',...
    'Position',[110,5,100,20],...
    'Tag','batchff_PushbuttonClearMsg',...
    'callback',@batchff_PushbuttonClearMsg);

% initialize message
feval(get(findall(hFigBatchFF,'tag','batchff_PushbuttonClearMsg'),'callback'));

function batchff_PushbuttonLoadPath(~,~)
hFigBatchFF = gcbf;
udata = get(hFigBatchFF,'UserData');
% load path
if isempty(udata.path), oldpath = pwd; else oldpath = udata.path; end
path = uigetdir(oldpath,'Load Image Path');
if path == 0, return; else udata.path = path; end
% update path
if isempty(udata.path), return; end;
a = [dir(fullfile(udata.path,'*.tif'));
    dir(fullfile(udata.path,'*.tiff'));
    dir(fullfile(udata.path,'*.cbf'))];
if isempty(a)
    info_added = {['Loaded path ',path];'No valid image file is found.';' '};
    updateinfo(hFigBatchFF,info_added);
    return; 
end
udata.flist = {a.name}';
% assign targe path
if isempty(udata.targetpath), udata.targetpath = udata.path; end
% save
set(hFigBatchFF,'UserData',udata);
info_added = {['Loaded path ',path];...
    [num2str(length(udata.flist)),' image files are found'];...
    ['Target path is ',udata.targetpath];...
    ' '};
updateinfo(hFigBatchFF,info_added);

function batchff_PushbuttonLoadFF(~,~)
hFigBatchFF = gcbf;
udata = get(hFigBatchFF,'UserData');
oldpath = pwd;
if ~isempty(udata.path), cd(udata.path); end
[filename,pathname] = uigetfile({'*.tif;*.tiff;'},'Load Flat Field File');
cd(oldpath); 
if isequal(filename,0), return; end
f = fullfile(pathname,filename);
[~,~,ext] = fileparts(f);
if ~strcmpi(ext,'.tif') && ~strcmpi(ext,'.tiff'), return; end
udata.fffile = f;
udata.ff = double(imread(f));
set(hFigBatchFF,'UserData',udata);
info_added = {['Loaded flat field file ',udata.fffile];
    ' '};
updateinfo(hFigBatchFF,info_added);

function batchff_PushbuttonLoadTargetPath(~,~)
hFigBatchFF = gcbf;
udata = get(hFigBatchFF,'UserData');
% load path
if isempty(udata.targetpath), oldpath = pwd; else oldpath = udata.targetpath; end
path = uigetdir(oldpath,'Load Target Path');
if path == 0, return; else udata.targetpath = path; end
% save
set(hFigBatchFF,'UserData',udata);
info_added = {['Loaded target path ',udata.targetpath];...
    ' '};
updateinfo(hFigBatchFF,info_added);

function batchff_EditPrefix(~,~)
hFigBatchFF = gcbf;
udata = get(hFigBatchFF,'UserData');
hEdit = findall(hFigBatchFF,'tag','batchff_EditPrefix');
prefix = get(hEdit,'string');
if isempty(prefix) || ~isvarname(prefix)
    prefix = 'FF_';
    set(hEdit,'string',prefix);
    udata.prefix = 'FF_'; 
else
    udata.prefix = prefix;
end
set(hFigBatchFF,'UserData',udata);
info_added = {['Prefix is ',udata.prefix];...
    ' '};
updateinfo(hFigBatchFF,info_added);

function batchff_PopupmenuBit(~,~)
hFigBatchFF = gcbf;
udata = get(hFigBatchFF,'UserData');
hPopumenuBit = findall(hFigBatchFF,'tag','batchff_PopupmenuBit');
datatype = get(hPopumenuBit,'string');
udata.bit = datatype{get(hPopumenuBit,'value')};
set(hFigBatchFF,'UserData',udata);
info_added = {['Export image type is ',udata.bit];...
    ' '};
updateinfo(hFigBatchFF,info_added);


function batchff_PushbuttonClearMsg(~,~)
hFigBatchFF = findall(0,'Tag','batchff_fig');
hEdit = findall(hFigBatchFF,'tag','batchff_msg');
info = {'Flat field correction in batch mode. Instruction:';...
    '1. Load image path. Only TIF/TIFF and CBF formats are supported.';...
    '2. Load flat field file (TIF/TIFF). FF will be applied by multiplication.';....
    '3. Indicate a target image file path. Default: source image path';...    
    '4. Enter prefix for export TIF file names. Default: ''FF_''';...
    '5. Select export image type. Default: int32';...
    '6. Start.'};
set(hEdit,'String',info);

function batchff_PushbuttonStart(~,~)
hFigBatchFF = gcbf;
udata = get(hFigBatchFF,'UserData');
if isempty(udata.flist) || isempty(udata.ff)
    return; 
end;
set(gcbo,'enable','off');
info_added = {'Start Processing ...';' '};
updateinfo(hFigBatchFF,info_added);  
warning off MATLAB:tifftagsread:unknownTagPayloadState;
for ii=1:length(udata.flist)
    pause(0.1);
    source_file = fullfile(udata.path,udata.flist{ii});    
    [~,name,ext] = fileparts(source_file);        
    % load data and info
    if strcmpi(ext,'.tif') || strcmpi(ext,'.tiff')
        imgdata = double(imread(source_file));
        imginfo = imfinfo(source_file);
    elseif strcmpi(ext,'.cbf')
        tmp =   cbfread(source_file);
        imgdata = double(tmp.data');
        imginfo = [];
    else
        continue;
    end
    % make target file name
    target_file = fullfile(udata.targetpath,[udata.prefix,name,'.tif']);
    while exist(target_file,'file') 
        [pathstr,namestr,~] = fileparts(target_file);
         target_file = fullfile(pathstr,['FF_',namestr,'.tif']);
    end    
    % correction
    if ~isequal(size(imgdata),size(udata.ff))
        info_added = [num2str(ii),' of ',num2str(length(udata.flist)),': ',udata.flist{ii},': Correction failed.'];
        updateinfo(hFigBatchFF,info_added);        
        continue;
    end
    imgdata = imgdata.*udata.ff;
    imwrite2tif(imgdata,imginfo,target_file,udata.bit);
        info_added = [num2str(ii),' of ',num2str(length(udata.flist)),': ',udata.flist{ii},': Successful.'];
        updateinfo(hFigBatchFF,info_added);        
end
set(gcbo,'enable','on');

function updateinfo(hFigBatchFF,info_added)
hEdit = findall(hFigBatchFF,'tag','batchff_msg');
info = get(hEdit,'String');
info = [info_added; info];
set(hEdit,'String',info);