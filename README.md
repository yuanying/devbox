# A Docker image for my development environment

> **Deprecated — this repository has moved.** It now lives in
> [yuanying/dotfiles](https://github.com/yuanying/dotfiles) as the `devbox/`
> directory. The history came along with it, so `git blame devbox/Dockerfile`
> over there still reaches the commits made here.
>
> The image and those dotfiles always changed together: the container clones
> them and runs `bin/setup.sh`, and the tool versions pinned in the
> `Dockerfile` are what the Mac setup script installs. Keeping the two apart
> meant two pull requests for one change, and a version written out twice.

```
$ git clone https://github.com/yuanying/dotfiles && cd dotfiles/devbox
$ make image        # CPU; `make cuda` and `make rocm` for the GPU variants
$ ./start-daemon
```

## License

MIT
