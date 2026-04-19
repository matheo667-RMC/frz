-- CreateTable
CREATE TABLE "FivemLink" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "license" TEXT,
    "citizenid" TEXT,
    "linkedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FivemLink_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "FivemLink_userId_key" ON "FivemLink"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "FivemLink_code_key" ON "FivemLink"("code");

-- CreateIndex
CREATE UNIQUE INDEX "FivemLink_license_key" ON "FivemLink"("license");

-- CreateIndex
CREATE UNIQUE INDEX "FivemLink_citizenid_key" ON "FivemLink"("citizenid");
