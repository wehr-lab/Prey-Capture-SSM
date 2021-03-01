function newpath=macifypath(path)
%convert a  windows path to a remote mac path

%to-do: this could be split into a macify function separate from a
%local-to-remote function. For now mac is the only remote use case.
if ~ismac return, end

newpath= strrep(path, '\', '/');
newpath= strrep(newpath, 'D:', '/Volumes/wehrrig4.uoregon.edu');
