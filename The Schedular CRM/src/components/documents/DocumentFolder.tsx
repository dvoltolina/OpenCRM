import type { DocumentFolder } from '../../types/documents';

interface DocumentFolderProps {
  folders: DocumentFolder[];
  activeFolderId?: string | null;
  onSelect?: (folderId: string | null) => void;
  onCreateFolder?: (parentId?: string) => void;
}

export function DocumentFolderTree({
  folders,
  activeFolderId,
  onSelect,
  onCreateFolder,
}: DocumentFolderProps) {
  const roots = folders.filter((folder) => !folder.parentFolderId);

  return (
    <div className="document-folder-tree">
      <div className="folder-header">
        <h4>Folders</h4>
        {onCreateFolder && (
          <button type="button" onClick={() => onCreateFolder()}>
            + Folder
          </button>
        )}
      </div>
      <ul>
        <li className={!activeFolderId ? 'active' : ''}>
          <button type="button" onClick={() => onSelect?.(null)}>
            All Documents
          </button>
        </li>
        {roots.map((folder) => (
          <FolderNode
            key={folder.id}
            folder={folder}
            folders={folders}
            depth={0}
            activeFolderId={activeFolderId}
            onSelect={onSelect}
            onCreateFolder={onCreateFolder}
          />
        ))}
      </ul>
    </div>
  );
}

interface FolderNodeProps {
  folder: DocumentFolder;
  folders: DocumentFolder[];
  depth: number;
  activeFolderId?: string | null;
  onSelect?: (folderId: string) => void;
  onCreateFolder?: (parentId?: string) => void;
}

function FolderNode({
  folder,
  folders,
  depth,
  activeFolderId,
  onSelect,
  onCreateFolder,
}: FolderNodeProps) {
  const children = folders.filter((child) => child.parentFolderId === folder.id);

  return (
    <li className={activeFolderId === folder.id ? 'active' : ''}>
      <div className="folder-row" style={{ paddingLeft: depth * 12 }}>
        <button type="button" onClick={() => onSelect?.(folder.id)}>
          {folder.name}
        </button>
        {onCreateFolder && (
          <button type="button" onClick={() => onCreateFolder(folder.id)} aria-label="Add subfolder">
            +
          </button>
        )}
      </div>
      {children.length > 0 && (
        <ul>
          {children.map((child) => (
            <FolderNode
              key={child.id}
              folder={child}
              folders={folders}
              depth={depth + 1}
              activeFolderId={activeFolderId}
              onSelect={onSelect}
              onCreateFolder={onCreateFolder}
            />
          ))}
        </ul>
      )}
    </li>
  );
}
