.PHONY: image citest test

IMAGE_NAME ?= codeclimate/codeclimate-markdownlint

image:
	docker build --rm -t $(IMAGE_NAME) .

citest: image
	docker run \
		--name "markdownlint-${CIRCLE_WORKFLOW_ID}" \
		--workdir /usr/src/app \
		$(IMAGE_NAME) bundle exec rake
	docker cp "markdownlint-${CIRCLE_WORKFLOW_ID}":/usr/src/app/coverage ./coverage

test: image
	docker run \
		--workdir /usr/src/app \
		$(IMAGE_NAME) bundle exec rake
