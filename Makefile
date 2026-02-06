IMAGE := registry.fraction.jp/yuanying/devbox

.PHONY: image
image:
		docker build \
			--target user_base -t $(IMAGE)-amd64:user_base \
			--target main -t $(IMAGE)-amd64 .
.PHONY: arm64
arm64:
		docker build \
			-f Dockerfile.arm64 \
			--target user_base -t $(IMAGE)-arm64:user_base \
			--target main -t $(IMAGE)-arm64 .
.PHONY: rocm
rocm:
		docker build \
			-f Dockerfile.rocm \
			--target user_base -t $(IMAGE)-rocm:user_base \
			--target main -t $(IMAGE)-rocm .
