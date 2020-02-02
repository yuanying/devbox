IMAGE := yuanying/devbox

.PHONY: image
image:
		docker build \
			--target user_base -t $(IMAGE):user_base \
			--target ruby_builder -t $(IMAGE):ruby_builder \
			--target main -t $(IMAGE) .

