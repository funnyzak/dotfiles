#!/usr/bin/env node

/**
 * Swagger API 文档路径保留器
 *
 * 一个通用的 Node.js 脚本，用于从 Swagger/OpenAPI 的 JSON 文档中，
 * 保留指定前缀的 API 路径（paths），并将结果保存到新文件中。
 * 脚本支持命令行参数模式和交互式输入模式，以适应不同的使用场景。
 *
 * 功能说明:
 * - 从原始 Swagger 文档中提取指定前缀的 API 路径
 * - 保留匹配前缀的所有路径，移除不匹配的路径
 * - 生成新的 Swagger 文档，保持原有结构和元数据
 *
 * 使用方式:
 *
 * 1. 命令行模式 (推荐用于自动化或脚本):
 *
 *   示例 1: 保留单个前缀的路径
 *   node swagger-filter.js --input api-docs.json --output filtered.json --include /open/api
 *
 *   示例 2: 保留多个前缀的路径
 *   node swagger-filter.js --input api-docs.json --output filtered.json --include /open/api,/public/v1
 *
 *   参数说明:
 *   --input <文件路径>     : 必需。指定输入的原始 Swagger JSON 文件路径
 *   --output <文件路径>    : 可选。指定过滤后的 JSON 文件保存路径，默认为 'filtered-swagger.json'
 *   --include <前缀列表>   : 必需。指定要保留的路径前缀，多个前缀用逗号 ',' 分隔
 *
 * 2. 交互式模式 (适用于手动操作):
 *
 *   直接运行脚本，不带任何参数:
 *   node swagger-filter.js
 *
 *   脚本将自动进入交互模式，引导你依次输入所需信息。
 *
 * @author 开发工程师
 * @version 2.0
 * @date 2025-01-15
 * @updated 2025-01-15 - 修改为保留指定前缀，而非排除
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// 创建一个用于命令行交互的接口
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

/**
 * 核心过滤函数 - 保留指定前缀的路径
 * @param {object} pathsObj 原始的 paths 对象
 * @param {string[]} includePrefixes 要保留的路径前缀数组
 * @returns {object} 过滤后的 paths 对象，只包含匹配前缀的路径
 */
function filterPaths(pathsObj, includePrefixes) {
  const filteredPaths = {};
  for (const key in pathsObj) {
    if (Object.prototype.hasOwnProperty.call(pathsObj, key)) {
      const shouldInclude = includePrefixes.some(prefix => key.startsWith(prefix));
      if (shouldInclude) {
        filteredPaths[key] = pathsObj[key];
      }
    }
  }
  return filteredPaths;
}

/**
 * 处理 JSON 文件并执行过滤操作
 * @param {string} inputPath 输入文件路径
 * @param {string} outputPath 输出文件路径
 * @param {string[]} includePrefixes 要保留的路径前缀数组
 */
function processFile(inputPath, outputPath, includePrefixes) {
  try {
    const rawData = fs.readFileSync(path.resolve(inputPath), 'utf8');
    const swaggerDoc = JSON.parse(rawData);

    if (!swaggerDoc.paths || typeof swaggerDoc.paths !== 'object') {
      throw new Error('JSON 文件中没有找到 "paths" 对象或其格式不正确。');
    }

    // 备份原始路径数量用于统计
    const originalPathCount = Object.keys(swaggerDoc.paths).length;

    console.log(`\n正在从文件 "${inputPath}" 中保留指定前缀的路径...`);

    const filteredPaths = filterPaths(swaggerDoc.paths, includePrefixes);

    // 更新原始文档的 paths 对象
    swaggerDoc.paths = filteredPaths;

    fs.writeFileSync(path.resolve(outputPath), JSON.stringify(swaggerDoc, null, 2), 'utf8');

    const retainedPathCount = Object.keys(filteredPaths).length;
    const removedPathCount = originalPathCount - retainedPathCount;

    console.log('--- 任务完成 ---');
    console.log(`成功将过滤后的内容保存到文件: "${outputPath}"`);
    console.log(`原始路径数量: ${originalPathCount}, 保留路径数量: ${retainedPathCount}, 移除路径数量: ${removedPathCount}`);
  } catch (error) {
    console.error(`\n执行脚本时出错: ${error.message}`);
    process.exit(1);
  } finally {
    rl.close();
  }
}

/**
 * 命令行模式处理函数
 * 解析命令行参数并执行相应操作
 */
function runWithCliArgs() {
  const args = process.argv.slice(2);
  const inputIndex = args.indexOf('--input');
  const outputIndex = args.indexOf('--output');
  const includeIndex = args.indexOf('--include');

  let inputPath = inputIndex !== -1 ? args[inputIndex + 1] : null;
  let outputPath = outputIndex !== -1 ? args[outputIndex + 1] : 'filtered-swagger.json';
  let includePrefixes = includeIndex !== -1 ? args[includeIndex + 1].split(',').map(s => s.trim()) : [];

  // 如果缺少必要的参数，则进入交互模式
  if (!inputPath || includePrefixes.length === 0) {
    console.log('缺少必要的命令行参数，将进入交互模式。');
    runInteractive();
  } else {
    processFile(inputPath, outputPath, includePrefixes);
  }
}

/**
 * 交互模式处理函数
 * 通过交互式输入获取所需参数
 */
function runInteractive() {
  rl.question('请输入要过滤的 Swagger JSON 文件路径 (默认: api-docs.json): ', (inputPath) => {
    inputPath = inputPath.trim() || 'api-docs.json';

    rl.question('请输入要保存的输出文件路径 (默认: filtered-swagger.json): ', (outputPath) => {
      outputPath = outputPath.trim() || 'filtered-swagger.json';

      rl.question('请输入要保留的路径前缀，多个前缀用逗号分隔 (默认: /open): ', (prefixesStr) => {
        prefixesStr = prefixesStr.trim() || '/open';
        const includePrefixes = prefixesStr.split(',').map(s => s.trim()).filter(s => s.length > 0);
        processFile(inputPath, outputPath, includePrefixes);
      });
    });
  });
}

// 主程序入口 - 根据是否有命令行参数来决定运行模式
if (process.argv.length > 2) {
  runWithCliArgs();
} else {
  console.log('\n未检测到命令行参数，将启动交互式模式。');
  runInteractive();
}
