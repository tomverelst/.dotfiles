set -gx USE_GKE_GCLOUD_AUTH_PLUGIN true

if [ -f "$HOME/.gcloud/path.fish.inc" ];
  . "$HOME/.gcloud/path.fish.inc";
end