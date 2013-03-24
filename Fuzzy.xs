#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define FAIL_STATUS
#define ERROR_HANDLER perl_error_handler

#include "text-fuzzy.h"
#include "text-fuzzy-perl.c"

#undef FAIL_STATUS
#define FAIL_STATUS

typedef text_fuzzy_t * Text__Fuzzy;

MODULE=Text::Fuzzy PACKAGE=Text::Fuzzy

PROTOTYPES: ENABLE

Text::Fuzzy
new (class, search_term, ...)
	const char * class;
	SV * search_term;
CODE:
	int i;
	text_fuzzy_t * r;

	/* Set the error handler in "text-fuzzy.c" to be the error
	   handler defined in "text-fuzzy-perl.c". This should be in
	   the "boot" routine rather than in the class initialization
	   routine. */

	text_fuzzy_error_handler = perl_error_handler;

	sv_to_text_fuzzy (search_term, & r);

        if (! r) {
        	croak ("error making %s.\n", class);
	}

	for (i = 2; i < items; i++) {
		SV * x;
		char * p;
		int len;

		if (i >= items - 1) {
			warn ("Odd number of parameters %d of %d", i, items);
			break;
		}

		/* Read in parameters in the "form max => 22",
		"no_exact => 1", etc. */

		x = ST (i);
		p = SvPV (x, len);
		if (strncmp (p, "max", strlen ("max")) == 0) {
			r->max_distance = SvIV (ST (i + 1));
		}
		else if (strncmp (p, "no_exact", strlen ("no_exact")) == 0) {
			r->no_exact = SvTRUE (ST (i + 1)) ? 1 : 0;
		}
		else if (strncmp (p, "trans", strlen ("trans")) == 0) {
			r->transpositions_ok = SvTRUE (ST (i + 1)) ? 1 : 0;
		}
		else {
			warn ("Unknown parameter %s", p);
		}
		/* Plan to throw one away; you will anyway. */
		i++;
	}
	RETVAL = r;
OUTPUT:
        RETVAL

SV *
get_max_distance (tf)
	Text::Fuzzy tf;
CODE:
        if (tf->max_distance >= 0) {
		RETVAL = newSViv (tf->max_distance);
	}
	else {
		RETVAL = &PL_sv_undef;
	}
OUTPUT:
	RETVAL

void
set_max_distance (tf, max_distance = &PL_sv_undef)
	Text::Fuzzy tf;
	SV * max_distance;
CODE:
        if (SvOK (max_distance)) {
		tf->max_distance = (int) SvIV (max_distance);
	}
	else {
        	tf->max_distance = NO_MAX_DISTANCE;
	}


void
transpositions_ok (tf, trans)
	Text::Fuzzy tf;
	SV * trans;
CODE:
	if (SvTRUE (trans)) {
		tf->transpositions_ok = 1;
	}
	else {
		tf->transpositions_ok = 0;
	}

int
get_trans (tf)
	Text::Fuzzy tf;
CODE:
	RETVAL = tf->transpositions_ok;
OUTPUT:
	RETVAL

int
distance (tf, word)
	Text::Fuzzy tf;
        SV * word;
CODE:
	RETVAL = text_fuzzy_sv_distance (tf, word);
OUTPUT:
	RETVAL

void
nearest (tf, words)
	Text::Fuzzy tf;
        AV * words;
PPCODE:
	int i;
	int n;
	AV * wantarray;

	wantarray = 0;

	if (GIMME_V == G_ARRAY) {
		wantarray = newAV ();
		n = text_fuzzy_av_distance (tf, words, wantarray);
	}
	else {
		n = text_fuzzy_av_distance (tf, words, 0);
	}
	/* We could check for void context and return here I suppose ... */
	if (wantarray) {
		EXTEND (SP, av_len (wantarray));
		for (i = 0; i <= av_len (wantarray); i++) {
			PUSHs (sv_2mortal (*(av_fetch (wantarray, i, 0))));
		}
        }
        else {
            PUSHs (sv_2mortal (newSViv (n)));
        }

int
last_distance (tf)
	Text::Fuzzy tf;
CODE:
	RETVAL = tf->distance;
OUTPUT:
	RETVAL

SV *
unicode_length (tf)
	Text::Fuzzy tf;
CODE:
        if (tf->text.unicode) {
		RETVAL = newSViv (tf->text.ulength);
	}
	else {
		RETVAL = &PL_sv_undef;
	}
OUTPUT:
	RETVAL


void
no_alphabet (tf, yes_no)
	Text::Fuzzy tf;
        SV * yes_no;
CODE:
	tf->user_no_alphabet = SvTRUE (yes_no);
	if (tf->user_no_alphabet) {
		tf->use_alphabet = 0;
		tf->use_ualphabet = 0;
	}

int
ualphabet_rejections (tf)
	Text::Fuzzy tf;
CODE:
	RETVAL = tf->ualphabet.rejections;
OUTPUT:
        RETVAL


int
length_rejections (tf)
	Text::Fuzzy tf;
CODE:
	RETVAL = tf->length_rejections;
OUTPUT:
        RETVAL


void
DESTROY (tf)
	Text::Fuzzy tf;
CODE:
	text_fuzzy_free (tf);

char *
scan_file (tf, file_name)
	Text::Fuzzy tf;
        char * file_name;
CODE:
        TEXT_FUZZY (scan_file (tf, file_name, & RETVAL));
OUTPUT:
        RETVAL

void
no_exact (tf, yes_no)
	Text::Fuzzy tf;
	SV * yes_no;
CODE:
	tf->no_exact = SvTRUE (yes_no);
