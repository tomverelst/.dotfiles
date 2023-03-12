function mini --wraps='kubectl config set-context minikube' --wraps='kubectl config use-context minikube' --description 'alias mini kubectl config use-context minikube'
  kubectl config use-context minikube $argv; 
end
