#ifndef _AZARIFY_H_
#define _AZRAIFY_H_

#include <stddef.h>

/* Process the string enclosed in a large pre-allocated buffer of length n.
 * May truncate the output if the end of the buffer reached. Null termination guaranteed */
void azarify_process_buffer(char *buf, size_t n);

/* Process the null-terminated string in a dynamic buffer, 
 * The new length is returned if the second parameter is not NULL.
 * May reallocate data so the new pointer is returned */
char *azarify_process_string(char *str, size_t *n);

#endif 
