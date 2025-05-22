#!/usr/bin/env node
/**
 * JSON to Files Generator
 * =======================
 *
 * 这个脚本用于从JSON文件中提取数据并生成相应的文件。
 * 它可以遍历JSON中的数组，为每个项目创建单独的文件，
 * 还可以选择性地下载HTML内容中的媒体资源。
 *
 * 用法:
 *   node json-to-files.js [options] json1.json [json2.json...]
 *
 * 选项:
 *   -o, --output <dir>          输出目录路径 (默认: 当前目录)
 *   --listProp <prop>           JSON中包含项目列表的属性名 (默认: "list")
 *   --fileName <prop>           用作文件名的属性 (默认: "title")
 *   --fallbackFileName <prop>   如果主文件名属性为空时的备选属性 (默认: "name")
 *   --content <prop>            文件内容的属性名 (默认: "html")
 *   --fileExtension <ext>       生成文件的扩展名 (默认: "html")
 *   -d, --download              下载HTML中的媒体资源
 *   --assetsDir <dir>           媒体资源保存目录 (默认: "assets")
 *   --assetsPrefix <prefix>     资源文件名前缀 (默认: "")
 *   --baseUrl <url>             处理相对路径时的基础URL
 *   -p, --prefix <value>        为所有生成的文件名添加前缀
 *   -v, --verbose               显示详细的处理信息
 *   -h, --help                  显示帮助信息
 *
 * 示例:
 *   node json-to-files.js data.json -o ./output -d --assetsDir media
 *   node json-to-files.js articles.json --listProp articles --content body --fileExtension md
 *
 *   # 处理单个JSON文件
 *   node json-to-files.js data.json

 *   # 指定输出目录和文件扩展名
 *   node json-to-files.js data.json -o ./output --fileExtension md

 *   # 自定义JSON结构属性
 *   node json-to-files.js custom.json --listProp articles --fileName custom_title --content body

 *   # 启用资源下载
 *   node json-to-files.js data.json -d

 *   # 自定义资源目录和前缀
 *   node json-to-files.js data.json -d --assetsDir media --assetsPrefix img_

 *   # 处理相对路径资源
 *   node json-to-files.js data.json -d --baseUrl https://example.com/articles/

 *   # 处理多个文件并启用详细日志
 *   node json-to-files.js data1.json data2.json -v -d -o ./output
 *
 * JSON文件示例:
 * {
 *   "list": [
 *     {
 *       "title": "第一篇文章",
 *       "name": "article-1",
 *       "html": "<p>这是第一篇文章内容</p><img src='images/photo.jpg'><video src='videos/clip.mp4'></video>"
 *     },
 *     {
 *       "title": "第二篇文章",
 *       "name": "article-2",
 *       "html": "<p>这是第二篇文章内容</p><img src='https://example.com/image.jpg'>"
 *     }
 *   ]
 * }
 *
 * 也可以使用自定义的属性名:
 * {
 *   "articles": [
 *     {
 *       "custom_title": "自定义标题",
 *       "body": "# 这是Markdown内容\n\n这是正文。"
 *     }
 *   ]
 * }
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const url = require('url');

// 解析HTML中的媒体资源链接
function extractMediaUrls(html) {
  const imgRegex = /<img[^>]+src=["']([^"']+)["'][^>]*>/gi;
  const videoRegex = /<video[^>]+src=["']([^"']+)["'][^>]*>|<source[^>]+src=["']([^"']+)["'][^>]*>/gi;
  const audioRegex = /<audio[^>]+src=["']([^"']+)["'][^>]*>|<source[^>]+src=["']([^"']+)["'][^>]*>/gi;

  const urls = new Set();

  // 提取图片链接
  let match;
  while (match = imgRegex.exec(html)) {
    urls.add(match[1]);
  }

  // 提取视频链接
  while (match = videoRegex.exec(html)) {
    urls.add(match[1] || match[2]);
  }

  // 提取音频链接
  while (match = audioRegex.exec(html)) {
    urls.add(match[1] || match[2]);
  }

  return Array.from(urls);
}

// 下载单个资源文件
function downloadMedia(mediaUrl, outputPath, baseUrl, verbose) {
  return new Promise((resolve, reject) => {
    // 处理相对URL
    let fullUrl = mediaUrl;
    if (!mediaUrl.startsWith('http://') && !mediaUrl.startsWith('https://')) {
      if (baseUrl) {
        fullUrl = new URL(mediaUrl, baseUrl).href;
      } else {
        if (verbose) console.log(`跳过相对路径资源(未提供baseUrl): ${mediaUrl}`);
        resolve({ success: false, url: mediaUrl, error: 'No baseUrl for relative path' });
        return;
      }
    }

    // 创建目录
    const dir = path.dirname(outputPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    // 选择适当的协议
    const client = fullUrl.startsWith('https://') ? https : http;

    const request = client.get(fullUrl, response => {
      if (response.statusCode !== 200) {
        if (verbose) console.log(`下载失败: ${fullUrl} - HTTP ${response.statusCode}`);
        resolve({ success: false, url: mediaUrl, error: `HTTP ${response.statusCode}` });
        return;
      }

      const file = fs.createWriteStream(outputPath);
      response.pipe(file);

      file.on('finish', () => {
        file.close();
        if (verbose) console.log(`下载完成: ${fullUrl} -> ${outputPath}`);
        resolve({ success: true, url: mediaUrl, path: outputPath });
      });
    }).on('error', err => {
      fs.unlink(outputPath, () => {}); // 删除部分下载的文件
      if (verbose) console.log(`下载错误: ${fullUrl} - ${err.message}`);
      resolve({ success: false, url: mediaUrl, error: err.message });
    });

    request.setTimeout(30000, () => {
      request.destroy();
      fs.unlink(outputPath, () => {});
      if (verbose) console.log(`下载超时: ${fullUrl}`);
      resolve({ success: false, url: mediaUrl, error: 'Timeout' });
    });
  });
}

// 替换HTML中的资源链接为本地路径
function replaceMediaUrls(html, mediaMap) {
  let newHtml = html;

  for (const [originalUrl, localPath] of Object.entries(mediaMap)) {
    // 使用正则表达式替换所有实例
    const escapedUrl = originalUrl.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`(src=["'])${escapedUrl}(["'])`, 'g');
    newHtml = newHtml.replace(regex, `$1${localPath}$2`);
  }

  return newHtml;
}

// 解析命令行参数
function parseArgs() {
  const args = {
    jsonFiles: [],
    outputDir: process.cwd(),  // 默认为当前工作目录
    options: {
      listProp: 'list',        // 新增: 可配置的列表属性名
      fileName: 'title',
      fallbackFileName: 'name',
      content: 'html',
      fileExtension: 'html',
      verbose: false,
      prefix: '',
      download: false,         // 新增: 是否下载媒体资源
      assetsDir: 'assets',     // 新增: 媒体资源保存目录
      assetsPrefix: '',        // 新增: 资源文件名前缀
      baseUrl: null            // 新增: 处理相对路径的基础URL
    }
  };

  const argv = process.argv.slice(2);

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];

    if (arg === '-h' || arg === '--help') {
      showHelp();
      process.exit(0);
    } else if (arg === '-o' || arg === '--output') {
      args.outputDir = argv[++i] || args.outputDir;
    } else if (arg === '--listProp') {
      args.options.listProp = argv[++i] || args.options.listProp;
    } else if (arg === '--fileName') {
      args.options.fileName = argv[++i] || args.options.fileName;
    } else if (arg === '--fallbackFileName') {
      args.options.fallbackFileName = argv[++i] || args.options.fallbackFileName;
    } else if (arg === '--content') {
      args.options.content = argv[++i] || args.options.content;
    } else if (arg === '--fileExtension') {
      args.options.fileExtension = argv[++i] || args.options.fileExtension;
    } else if (arg === '-v' || arg === '--verbose') {
      args.options.verbose = true;
    } else if (arg === '-p' || arg === '--prefix') {
      args.options.prefix = argv[++i] || '';
    } else if (arg === '-d' || arg === '--download') {
      args.options.download = true;
    } else if (arg === '--assetsDir') {
      args.options.assetsDir = argv[++i] || args.options.assetsDir;
    } else if (arg === '--assetsPrefix') {
      args.options.assetsPrefix = argv[++i] || args.options.assetsPrefix;
    } else if (arg === '--baseUrl') {
      args.options.baseUrl = argv[++i] || null;
    } else if (arg.endsWith('.json')) {
      args.jsonFiles.push(arg);
    }
  }

  return args;
}

// 显示帮助信息
function showHelp() {
  const scriptName = path.basename(process.argv[1]);
  console.log(`
JSON to Files Generator

用法:
  node ${scriptName} [options] json1.json [json2.json...]

选项:
  -o, --output <dir>          输出目录路径 (默认: 当前目录)
  --listProp <prop>           JSON中包含项目列表的属性名 (默认: "list")
  --fileName <prop>           用作文件名的属性 (默认: "title")
  --fallbackFileName <prop>   如果主文件名属性为空时的备选属性 (默认: "name")
  --content <prop>            文件内容的属性名 (默认: "html")
  --fileExtension <ext>       生成文件的扩展名 (默认: "html")
  -d, --download              下载HTML中的媒体资源
  --assetsDir <dir>           媒体资源保存目录 (默认: "assets")
  --assetsPrefix <prefix>     资源文件名前缀 (默认: "")
  --baseUrl <url>             处理相对路径时的基础URL
  -p, --prefix <value>        为所有生成的文件名添加前缀
  -v, --verbose               显示详细的处理信息
  -h, --help                  显示帮助信息

示例:
  node ${scriptName} data.json -o ./output -d --assetsDir media
  node ${scriptName} articles.json --listProp articles --content body --fileExtension md
  `);
}

// 处理单个JSON文件
async function processJsonFile(jsonFile, args) {
  const { outputDir, options } = args;
  const {
    listProp,
    fileName,
    fallbackFileName,
    content,
    fileExtension,
    verbose,
    prefix,
    download,
    assetsDir,
    assetsPrefix,
    baseUrl
  } = options;

  if (verbose) {
    console.log(`处理文件: ${jsonFile}`);
  }

  try {
    // 读取JSON文件
    const jsonData = JSON.parse(fs.readFileSync(jsonFile, 'utf8'));

    // 检查是否有指定的列表属性
    if (!jsonData[listProp] || !Array.isArray(jsonData[listProp])) {
      if (verbose) {
        console.log(`未找到 '${listProp}' 数组属性，跳过文件: ${jsonFile}`);
      }
      return;
    }

    // 确保输出目录存在
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // 创建资源目录(如果需要下载资源)
    const assetsDirPath = path.join(outputDir, assetsDir);
    if (download && !fs.existsSync(assetsDirPath)) {
      fs.mkdirSync(assetsDirPath, { recursive: true });
    }

    // 处理列表中的每个项目
    for (let i = 0; i < jsonData[listProp].length; i++) {
      const item = jsonData[listProp][i];

      // 获取文件名和内容
      let outputFileName = item[fileName] || item[fallbackFileName] || `unnamed_${Date.now()}_${i}`;
      let outputContent = item[content] || '';

      // 添加前缀并清理文件名（移除非法字符）
      outputFileName = prefix + outputFileName;
      outputFileName = outputFileName.replace(/[/\\?%*:|"<>]/g, '-').trim();

      // 构建完整的文件路径
      const outputFilePath = path.join(outputDir, `${outputFileName}.${fileExtension}`);

      // 如果需要下载资源
      if (download && fileExtension.toLowerCase() === 'html') {
        const mediaUrls = extractMediaUrls(outputContent);

        if (mediaUrls.length > 0 && verbose) {
          console.log(`在 ${outputFileName} 中找到 ${mediaUrls.length} 个媒体资源链接`);
        }

        // 下载所有媒体资源
        const mediaMap = {};
        const downloadPromises = [];

        for (let j = 0; j < mediaUrls.length; j++) {
          const mediaUrl = mediaUrls[j];

          // 生成资源文件名
          const urlParts = mediaUrl.split('/');
          let assetFileName = urlParts[urlParts.length - 1];

          // 处理URL参数
          assetFileName = assetFileName.split('?')[0];

          // 添加前缀和索引以避免重名
          const uniqueAssetName = `${assetsPrefix}${i}_${j}_${assetFileName}`;
          const assetPath = path.join(assetsDirPath, uniqueAssetName);

          // 资源的相对路径(用于HTML替换)
          const relativePath = path.join(assetsDir, uniqueAssetName).replace(/\\/g, '/');

          // 添加下载任务
          downloadPromises.push(
            downloadMedia(mediaUrl, assetPath, baseUrl, verbose)
              .then(result => {
                if (result.success) {
                  mediaMap[mediaUrl] = relativePath;
                }
                return result;
              })
          );
        }

        // 等待所有下载完成
        if (downloadPromises.length > 0) {
          const results = await Promise.all(downloadPromises);
          const successCount = results.filter(r => r.success).length;

          if (verbose) {
            console.log(`下载完成: ${successCount}/${results.length} 个资源成功`);
          }

          // 替换内容中的URL
          outputContent = replaceMediaUrls(outputContent, mediaMap);
        }
      }

      // 写入文件
      fs.writeFileSync(outputFilePath, outputContent);

      if (verbose) {
        console.log(`创建文件: ${outputFilePath}`);
      }
    }

    if (verbose) {
      console.log(`成功处理 ${jsonData[listProp].length} 个项目，来自文件: ${jsonFile}`);
    }

    return jsonData[listProp].length; // 返回处理的项目数

  } catch (error) {
    console.error(`处理 ${jsonFile} 时出错: ${error.message}`);
    return 0;
  }
}

// 主函数
async function main() {
  const args = parseArgs();

  if (args.jsonFiles.length === 0) {
    console.error('错误: 未指定JSON文件');
    showHelp();
    process.exit(1);
  }

  let totalItemsProcessed = 0;

  for (const jsonFile of args.jsonFiles) {
    const itemsProcessed = await processJsonFile(jsonFile, args);
    totalItemsProcessed += itemsProcessed;
  }

  console.log(`处理完成: 共生成了 ${totalItemsProcessed} 个文件到 ${args.outputDir} 目录`);
}

// 执行主函数
main().catch(error => {
  console.error('执行错误:', error);
  process.exit(1);
});
