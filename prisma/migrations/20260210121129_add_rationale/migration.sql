/*
  Warnings:

  - Added the required column `rationale` to the `Decision` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE `Decision` ADD COLUMN `rationale` TEXT NOT NULL;
