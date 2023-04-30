UNAME_M := $(shell uname -p)
IMAGE := registry.fraction.jp/yuanying/devbox-$(UNAME_M)

.PHONY: image
image:
		docker build \
			--target user_base -t $(IMAGE):user_base \
			--target main -t $(IMAGE) .

