.PHONY: image test

IMAGE_NAME ?= codeclimate/codeclimate-markdownlint

image:
	docker build --rm -t $(IMAGE_NAME) .

test: image
	docker run --rm \
		--env CIRCLECI \
		--env CIRCLE_BUILD_NUM \
		--env CIRCLE_BRANCH \
		--env CIRCLE_SHA1 \
		--env CODECLIMATE_REPO_TOKEN \
		--workdir /usr/src/app \
		--volume "$(PWD)/.git:/usr/src/app/.git" \
		$(IMAGE_NAME) sh -c "bundle exec rake && bundle exec codeclimate-test-reporter"
