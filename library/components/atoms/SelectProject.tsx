import { Project } from "@/library/backendAPI";
import { Dispatch } from "react";

interface ProjectWithId extends Project {
  projectId: number;
}

export interface SelectProjectProps {
  ecoFundId: number;
  project: ProjectWithId;
  updateValues: Dispatch<Partial<{ showPersonalProjects: boolean }>>;
  addProjectToEcoFund: (
    ecoFundId: number,
    projectId: number,
    callback: () => void
  ) => Promise<void>;
}

const SelectProject = ({ props }: { props: SelectProjectProps }) => {
  function handleClick() {
    props.addProjectToEcoFund(props.ecoFundId, props.project.projectId, () => {
      alert("Project successfully added to ecoFund");
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
