# Copia de docker/dockerfiles/vite.Dockerfile apontando para a imagem base do ChatClean.
FROM chatclean:development

ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN chmod +x docker/entrypoints/vite.sh

EXPOSE 3036
CMD ["bin/vite", "dev"]
