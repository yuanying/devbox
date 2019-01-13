workflow "Build and Push" {
  on = "push"
  resolves = [
    "Build Docker image"
  ]
}

action "Build Docker image" {
  uses = "docker://docker:stable"
  args = ["hack/build.sh"]
}
