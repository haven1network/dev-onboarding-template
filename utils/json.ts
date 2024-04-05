/* IMPORT NODE MODULES
================================================== */
import * as fs from "fs";
import * as path from "path";

/* TYPES
================================================== */
type Obj = Record<string, unknown>;

/* WRITE
================================================== */
/**
 *  Basic implementation of a JSON file writer. It will prepend the filename
 *  with the current timestamp to avoid clashes. Cannot be used to append data.
 *
 *  If the dirname does not exist, this function will create it.
 *
 *  @function   writeJSON
 *  @param      {string}    filePath - The relative file path. Must end in ".json"
 *  @param      {Obj}       content -  The content to write.
 *  @returns    {boolean}   True is success, false otherwise.
 */
export function writeJSON(filePath: string, content: Obj): boolean {
    if (!filePath.endsWith(".json")) {
        return false;
    }

    const t = Date.now();

    let p = path.join(__dirname, filePath);
    let f = `${t}_${path.basename(p)}`;
    const dir = path.dirname(p);

    p = path.join(dir, f);

    const exists = fs.existsSync(dir);
    if (!exists) {
        fs.mkdirSync(dir, { recursive: true });
    }

    let d = "";

    try {
        d = JSON.stringify(content, null, 4);
    } catch (_) {
        return false;
    }

    try {
        fs.writeFileSync(p, d, "utf8");
    } catch (_) {
        return false;
    }

    return true;
}
