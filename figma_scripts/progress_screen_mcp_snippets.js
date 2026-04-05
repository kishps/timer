/**
 * Скрипты для mcp_figma_use_figma (fileKey: NtoQTYd62RYJyNGjaQOUTA).
 * Вставляйте содержимое каждого блока в параметр `code` по очереди после сброса лимита Figma MCP.
 * skillNames: "figma-use,figma-generate-design"
 */

// --- 1) ОБЁРТКА + AppBar + Body (пустой контейнер для секций) ---
/*
Возвращает wrapperId, bodyId — сохраните для следующих шагов.
*/

// --- 2) Карточка «Общая статистика» ---
// parent: await figma.getNodeByIdAsync("BODY_ID")

// --- 3) Карточки сравнения + тренд + диффы + PR ---
// parent: body

// --- 4) Упражнения, активность, последние тренировки ---
// parent: body
