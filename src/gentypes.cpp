#include "lang.h"

static void outputTreeDef(const struct lang &lang)
{
    FILE *f = fopen("tree.def", "w");

    fputs("/*\n"
          " * tree.def - Type definition for the `tree' structure.\n"
          " *\n"
          " * Automatically generated by gendef. DO NOT EDIT.\n"
          " */\n\n", f);

    for (auto const type : lang.treeTypes)
        fprintf(f, "DEFTYPE(%s, \"%s\")\n", type.name.c_str(),
                type.friendly_name.c_str());

    fclose(f);
}

static void usage(char *progname)
{
    fprintf(stderr, "%s - Generate the `tree.def' file from a language description\n",
            progname);
    fprintf(stderr, "Usage: %s LANG_DESC_FILE\n", progname);
    fprintf(stderr, "\n");
    fprintf(stderr, "Where LANG_DESC_FILE is a language description file.\n");
}

int main(int argc, char *argv[])
{
    struct lang lang;
    FILE *f;

    if (argc != 2) {
        fprintf(stderr, "Error: %s expects exactly one argument\n", argv[0]);
        usage(argv[0]);
        return 1;
    }

    f = fopen(argv[1], "r");

    if (!f) {
        perror("Could not open lang file");
        usage(argv[0]);
        exit(2);
    }

    lang_read(f, lang);

    outputTreeDef(lang);

    return 0;
}
