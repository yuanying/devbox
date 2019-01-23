IMAGE := yuanying/devbox

.PHONY: image
image:
		docker build -t $(IMAGE) .
