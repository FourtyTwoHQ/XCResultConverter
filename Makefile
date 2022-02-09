build:
	@echo 'Building Debug'
	@swift build -c debug

build-release:
	@echo 'Building Release'
	@swift build -c release

clean:
	@echo 'Removing Artifacts'
	@rm -rf .build

install: rebuild-release
	$(eval env_arch := $(shell arch))
	cp .build/$(env_arch)-apple-macosx/release/xcrc /usr/local/bin

package-release: rebuild-release
	$(eval env_arch := $(shell arch))
	@tar -czf xcrc.tar.gz --directory=.build/$(env_arch)-apple-macosx/release xcrc
	@shasum -a 256 xcrc.tar.gz

rebuild: clean build

rebuild-release: clean build-release

test:
	@swift test
