#pragma once

struct OSDevice {
    const s8* (*getPathToExecutable)();
    void (*readBinaryFile)(const s8* fileName, u8** fileData, u64* fileLength);
    void (*readTextFile)(const s8* fileName, s8** fileData, u64* fileLength);
};