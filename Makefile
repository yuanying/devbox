IMAGE := yuanying/devbox

.PHONY: image
image:
		docker build \
			--target tmux_plugins_builder -t $(IMAGE):tmux \
			--target kubectl_builder -t $(IMAGE):kubectl \
			--target onepassword_builder -t $(IMAGE):op \
			--target linuxbrew_installer -t $(IMAGE):brew \
			--target golang_installer -t $(IMAGE):golang \
			--target main -t $(IMAGE) .
