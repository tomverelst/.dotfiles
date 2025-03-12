function ls --wraps=exa --wraps=lsd --wraps='eza --icons' --description 'alias ls=eza --icons'
  eza --icons $argv; 
end
