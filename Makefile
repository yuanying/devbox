IMAGE := registry.fraction.jp/yuanying/devbox

.PHONY: image
image:
		docker build \
			--target user_base -t $(IMAGE):user_base \
			--target main -t $(IMAGE) .

