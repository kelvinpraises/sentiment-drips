import CheckList from "@editorjs/checklist";
import Code from "@editorjs/code";
import Delimiter from "@editorjs/delimiter";
import Header from "@editorjs/header";
import Link from "@editorjs/link";
import List from "@editorjs/list";
import Paragraph from "@editorjs/paragraph";
import Image from "@editorjs/image";

export const EDITOR_JS_TOOLS = {
  code: Code,
  paragraph: {
    class: Paragraph,
    inlineToolbar: true,
  },
  checkList: CheckList,
  list: List,
  header: Header,
  delimiter: Delimiter,
  image: Image,
  link: {
    class: Link,
    config: {
      endpoint: "http://127.0.0.1:3002/fetchUrl", // Your backend endpoint for url data fetching,
    },
  },
};
