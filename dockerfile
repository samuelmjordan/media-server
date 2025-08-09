FROM ocaml/opam:alpine-ocaml-5.1

ENV DATA_DIRECTORY="/data/films"

# ffmpeg + all the deps ocaml apparently needs
RUN sudo apk add --no-cache \
    ffmpeg \
    postgresql-dev \
    pkgconfig \
    gcc \
    musl-dev \
    make \
    gmp-dev \
    libev-dev

# switch to opam user
USER opam
WORKDIR /home/opam

# copy rest of project
COPY --chown=opam:opam . .

# copy opam files first for better caching
COPY --chown=opam:opam dune-project nautilus.opam ./

# install deps from opam file
RUN eval $(opam env) && \
    opam update && \
    opam install -y --deps-only .

# build the thing
RUN eval $(opam env) && \
    dune build

# dream web server probably wants this
EXPOSE 8080

CMD ["sh", "-c", "eval $(opam env) && dune exec nautilus"]