/**
 * Function to check all required ENV vars are present and return the missing
 * ones. If the length of the returned array is not zero (0), there are missing
 * ENV vars and it can be handled by the calling code as desired.
 *
 * @function    checkENV
 * @param       {string[]}  vars    List of vars to check
 * @returns     {string[]}  Array of missing environment variables
 */
export function checkENV(vars: string[]): string[] {
    const missingEnvVars: string[] = [];

    for (const v of vars) {
        if (!process.env[v]) {
            missingEnvVars.push(v);
        }
    }

    return missingEnvVars;
}
