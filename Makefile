IMAGE := yuanying/devbox

.PHONY: image
image:
		docker build \
			--target main -t $(IMAGE) .

