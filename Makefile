ARCH := $(shell dpkg --print-architecture)
IMAGE := registry.fraction.jp/yuanying/devbox-$(ARCH)

.PHONY: image
image:
		docker build \
			--target user_base -t $(IMAGE):user_base \
			--target main -t $(IMAGE) .

