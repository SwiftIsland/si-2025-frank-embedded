file(GLOB_RECURSE TIFF_IMAGES files/*.tiff)
idf_component_register(SRCS "src/resources.c"
                       INCLUDE_DIRS "include"
                       EMBED_TXTFILES ${TIFF_IMAGES})