function [out] = NP_UnpackStructArray(StructArray,field)
% [out] = NP_UnpackStructArray(StructArray,field)
% couldn't find how to do this with a built-in function so I made my own
% if you're not passing an array of structs, you're wrong

example =  getfield(StructArray(1),field);

if (ndims(example) == 1) 
  for i = 1:length(StructArray)
    out(i) = getfield(StructArray(i),field);
  end
else
  [val,idx] = max(size(example));
  if (idx == 1)
    for i = 1:length(StructArray)
      out(:,i) = getfield(StructArray(i),field);
    end
  else
    for i = 1:length(StructArray)
      out(:,i) = getfield(StructArray(i),field);
    end
  end
end


