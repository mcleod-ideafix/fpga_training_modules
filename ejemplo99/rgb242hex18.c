#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char *argv[])
{
	FILE *f;
	unsigned char *scr;
	char nombre[256];
	int i,leido;
    unsigned r,g,b,color18;
	
	if (argc<2)
		return 1;
	
	scr = malloc(65536);
	f = fopen (argv[1],"rb");
	if (!f)
		return 1;
		
	leido = fread (scr, 1, 65536, f);
	fclose (f);
	
	strcpy (nombre, argv[1]);
	nombre[strlen(nombre)-3]=0;
	strcat (nombre, "hex");
	
	f = fopen (nombre, "wt");
	for (i=0;i<leido;i+=3)
    {
        r = scr[i]/4;
        g = scr[i+1]/4;
        b = scr[i+2]/4;
        color18 = (r<<12) | (g<<6) | b;
  	   fprintf (f, "%.5X\n", color18);
    }
	fclose(f);
	
	return 0;
}

