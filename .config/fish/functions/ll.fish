function ll --wraps='lsd -al' --wraps='eza -l -g --icons' --description 'alias ll=eza -l -g --icons'
  eza -l -g --icons $argv; 
end
