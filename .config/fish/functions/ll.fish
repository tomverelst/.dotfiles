function ll --wraps='exa -l' --wraps='exa -al' --description 'alias ll=exa -al'
  exa -al $argv; 
end
