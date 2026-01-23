function ll --wraps='eza -a -1 --icons --group-directories-first' --description 'ls list'
  eza -a -1 --icons --group-directories-first $argv;
end
