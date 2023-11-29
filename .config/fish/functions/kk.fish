function kk --wraps='kubectl -n kannika-system' --description 'alias kk=kubectl -n kannika-system'
  kubectl -n kannika-system $argv; 
end
