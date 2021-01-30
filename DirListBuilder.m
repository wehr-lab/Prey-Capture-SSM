function DirListBuilder(varargin)
%
% A GUI to create/append a machine readable datadir list
% this will be a text file with each dir you select
% uses a button to add current directory to a dir list file
%
% the idea of using a machine-readable txt file is that you can annotate
% the txt file with comments as long as you retain the "datadir" taglines
% modified from CellListBuilder to just build a list of directories 

global P

if nargin > 0
    action = varargin{1};
else
    action = get(gcbo,'tag');
end
if isempty(action)
    action='Init';
end


switch action
    case 'Init'
        InitializeGUI
    case 'Close'
        delete(P.fig)
        clear global P
    case 'CreateNewDirList'
        CreateNewDirList
    case 'SelectExistingDirList'
        SelectExistingDirList
    case 'SelectDirs'
        SelectDirs
    case 'TargetDirList'
        TargetDirList
end

% Return the name of this function.
function out = me
out = mfilename;

function CreateNewDirList
global P
[fname, path] = uiputfile('*.txt', 'Create a new dir list');
if fname
    P.TargetDirList=fullfile(path, fname);
    set(P.TargetDirListDisplay, 'string', {'dir list:',path, fname});
    set([P.SelectDirsh], 'enable', 'on')
end

function SelectExistingDirList
global P
[fname, path] = uigetfile('*.txt', 'Select dir list');
if fname
    P.TargetDirList=fullfile(path, fname);
    set(P.TargetDirListDisplay, 'string', {'dir list:',path, fname});
    set([P.SelectDirsh], 'enable', 'on')
end
UpdateListDisplay

function SelectDirs(d)
global P
dirlist = uipickfiles;
str='';
for i=1:length(dirlist)
    str=sprintf('%s\n\ndatadir',str);
    str=sprintf('%s\nPath: %s',str, dirlist{i});
end
%         %here we could write out any additional experimental details
%         %loaded from stimulus or notebook files etc
%     try
%         nb=load('notebook.mat');
%         str=sprintf('%s\nStim: %s',str, nb.stimlog(1).protocol_name);
%         str=sprintf('%s\n', str);
%     end
    
        fid=fopen(P.TargetDirList, 'a'); %absolute path
        fprintf(fid, '%s', str);
        fclose(fid);
        UpdateListDisplay
 

function UpdateListDisplay
global P
str=sprintf('!cat %s', P.TargetDirList');
set(P.DirListDisplay, 'string', evalc(str));

%resize windows to fit text
s=get(P.DirListDisplay, 'string');
numlines=size(s, 1);
figpos=get(P.fig, 'position');
boxpos=get(P.DirListDisplay, 'position');
pixperline=16; %pixels per line scale factor
boxpos(4)=pixperline*numlines;
boxpos(4)=max(boxpos(4), 220);
screensize = get( groot, 'Screensize' );
if boxpos(4)>screensize(4)
    str=sprintf('LIST TRUNCATED AT SCREENSIZE\n%s',evalc(str));
    set(P.DirListDisplay, 'string', str);
end
boxpos(4)=min(boxpos(4), screensize(4));
figpos(4)=boxpos(4)+2;
set(P.DirListDisplay, 'position', boxpos);
set(P.fig, 'position',figpos);
set(P.DirListDisplay, 'position', boxpos);


function InitializeGUI

global P
if isfield(P, 'fig')
    try
        close(P.fig)
    end
end
fig = figure;
P.fig=fig;
set(fig,'visible','off');
set(fig,'visible','off','numbertitle','off','name','dir list builder',...
    'doublebuffer','on','menubar','none','closerequestfcn','DirListBuilder(''Close'')')
height=250; width=300; e=5; H=e;
bigwidth=700;
w=200; h=25;
set(fig,'pos',[1000 800         bigwidth         height],'visible','on');


%TargetDirList display
P.TargetDirListDisplay= uicontrol('parent',fig,'string','','tag','TargetDirListDisplay','units','pixels',...
    'position',[e H width-e 2*h],'enable','on',...
    'fontweight','bold','horiz', 'left',...
    'style','text');

%gdindex List in progress display
P.DirListDisplay= uicontrol('parent',fig,'string','','tag','TargetDirListDisplay','units','pixels',...
    'position',[width e bigwidth-e height-e],'enable','on',...
    'fontweight','bold','horiz', 'left',...
    'style','text');

%CreateNewDirList button
H=H+2*h+e;
uicontrol('parent',fig,'string','Create New Dir List','tag','CreateNewDirList','units','pixels',...
    'position',[e H w h],'enable','on',...
    'fontweight','bold',...
    'style','pushbutton','callback',[me ';']);

%SelectExistingDirList button
H=H+1*h+e;
uicontrol('parent',fig,'string','Select Existing Dir List','tag','SelectExistingDirList','units','pixels',...
    'position',[e H w h],'enable','on',...
    'fontweight','bold',...
    'style','pushbutton','callback',[me ';']);



%SelectDirs button
H=H+h+e;
P.SelectDirsh=uicontrol('parent',fig,'string','Select Data Dirs','tag','SelectDirs','units','pixels',...
    'position',[e H w h],'enable','off',...
    'fontweight','bold',...
    'style','pushbutton','callback',[me ';']);











