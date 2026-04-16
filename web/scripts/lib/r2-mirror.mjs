/**
 * Cloudflare R2 이미지 미러링 헬퍼.
 *
 * R2는 S3 호환 API 제공 → @aws-sdk/client-s3 사용.
 * Bucket: $R2_BUCKET (예: bochoong-product-images)
 * Key:    products/{product_id}/{source}/{image_hash}.{ext}
 */

import { S3Client, PutObjectCommand, HeadObjectCommand } from "@aws-sdk/client-s3";
import { createHash } from "node:crypto";

let _client = null;

export function getR2Client() {
  if (_client) return _client;

  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;

  if (!accountId || !accessKeyId || !secretAccessKey) {
    throw new Error("R2_ACCOUNT_ID / R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY 미설정");
  }

  _client = new S3Client({
    region: "auto",
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId, secretAccessKey },
  });
  return _client;
}

export function getBucket() {
  const b = process.env.R2_BUCKET;
  if (!b) throw new Error("R2_BUCKET 미설정");
  return b;
}

export function getPublicUrl(key) {
  const base = process.env.R2_PUBLIC_URL_BASE;
  if (!base) return null;
  return `${base.replace(/\/$/, "")}/${key}`;
}

/** 이미지 URL을 fetch → Buffer + metadata. */
export async function fetchImage(url) {
  const res = await fetch(url, {
    headers: { "User-Agent": "bochoong-scraper/1.0 (+https://bochoong.com/about)" },
    redirect: "follow",
  });
  if (!res.ok) throw new Error(`fetch ${res.status}: ${url}`);

  const buffer = Buffer.from(await res.arrayBuffer());
  const contentType = res.headers.get("content-type") ?? "image/jpeg";
  const hash = createHash("sha256").update(buffer).digest("hex");

  const ext = guessExt(contentType, url);
  return { buffer, contentType, hash, ext, size: buffer.length };
}

function guessExt(contentType, url) {
  if (contentType.includes("png")) return "png";
  if (contentType.includes("webp")) return "webp";
  if (contentType.includes("gif")) return "gif";
  if (contentType.includes("jpeg") || contentType.includes("jpg")) return "jpg";
  const m = url.match(/\.(jpg|jpeg|png|webp|gif)(\?|$)/i);
  return m ? m[1].toLowerCase() : "jpg";
}

export function buildKey({ productId, source, hash, ext }) {
  return `products/${productId}/${source}/${hash}.${ext}`;
}

/** 동일 key 존재 여부 (HEAD). */
export async function exists(key) {
  const client = getR2Client();
  try {
    await client.send(new HeadObjectCommand({ Bucket: getBucket(), Key: key }));
    return true;
  } catch (e) {
    if (e.$metadata?.httpStatusCode === 404) return false;
    throw e;
  }
}

/** R2에 업로드 (이미 있으면 skip). */
export async function uploadToR2({ key, buffer, contentType }) {
  if (await exists(key)) return { uploaded: false, key };

  const client = getR2Client();
  await client.send(
    new PutObjectCommand({
      Bucket: getBucket(),
      Key: key,
      Body: buffer,
      ContentType: contentType,
      CacheControl: "public, max-age=31536000, immutable",
    }),
  );
  return { uploaded: true, key };
}
