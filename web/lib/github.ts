export interface ReleaseAsset {
  name: string
  browser_download_url: string
  size: number
  download_count: number
}

export interface Release {
  tag_name: string
  name: string
  published_at: string
  assets: ReleaseAsset[]
  html_url: string
}

export async function getLatestRelease(): Promise<Release | null> {
  try {
    const res = await fetch(
      'https://api.github.com/repos/hexadigitall/hom-os/releases/latest',
      {
        headers: {
          Accept: 'application/vnd.github.v3+json',
        },
        next: { revalidate: 3600 }, // cache 1 hour
      }
    )
    if (!res.ok) return null
    return res.json()
  } catch {
    return null
  }
}

export function findAsset(assets: ReleaseAsset[], keywords: string[]) {
  return assets.find((a) =>
    keywords.every((k) => a.name.toLowerCase().includes(k.toLowerCase()))
  )
}

export function formatBytes(bytes: number) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}
