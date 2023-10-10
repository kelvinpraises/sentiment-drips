import { Project } from "@/hooks/backendAPI";
import { Dispatch } from "react";

interface ProjectWithId extends Project {
  projectId: number;
}

export interface SelectProjectProps {
  docFundId: number;
  project: ProjectWithId;
  updateValues: Dispatch<Partial<{ showPersonalProjects: boolean }>>;
  addProjectToDocFund: (
    docFundId: number,
    projectId: number,
    callback: () => void
  ) => Promise<void>;
}

const SelectProject = ({ props }: { props: SelectProjectProps }) => {
  function handleClick() {
    props.addProjectToDocFund(props.docFundId, props.project.projectId, () => {
      alert("Project successfully added to DocFund");
    });

    props.updateValues({
      showPersonalProjects: false,
    });
  }

  return (
    <p className="cursor-pointer" onClick={handleClick}>
      {props.project.title}
    </p>
  );
};

export default SelectProject;
